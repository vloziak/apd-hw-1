import Foundation

public enum StudyCategory: String, Codable, CaseIterable {
    case reading, practice, project
}

public enum StudyPlanError: Error, Equatable {
    case blankTitle
    case nonPositiveEstimatedMinutes
    case duplicateID(String)
    case unknownID(String)
}

public struct StudyItem: Codable, Equatable {
    public let id: String
    public let title: String
    public let estimatedMinutes: Int
    public let category: StudyCategory
    public private(set) var isCompleted: Bool

    public init(
        id: String,
        title: String,
        estimatedMinutes: Int,
        category: StudyCategory,
        isCompleted: Bool = false
    ) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw StudyPlanError.blankTitle
        }
        
        guard estimatedMinutes > 0 else {
            throw StudyPlanError.nonPositiveEstimatedMinutes
        }
        
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.isCompleted = isCompleted
    }
    
    mutating func markAsCompleted() {
        isCompleted = true
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, estimatedMinutes, category, isCompleted
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        let category = try container.decode(StudyCategory.self, forKey: .category)
        let isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false

        try self.init(
            id: id,
            title: title,
            estimatedMinutes: estimatedMinutes,
            category: category,
            isCompleted: isCompleted
        )
    }
}

public struct StudyPlan: Codable, Equatable {
    public private(set) var items: [StudyItem]
    
    public init(items: [StudyItem]) throws {
        var seenIDs = Set<String>()
        for item in items {
            if seenIDs.contains(item.id) {
                throw StudyPlanError.duplicateID(item.id)
            }
            seenIDs.insert(item.id)
        }
        
        self.items = items.sorted { ($0.title, $0.id) < ($1.title, $1.id) }
    }
    
    private enum CodingKeys: String, CodingKey {
        case items
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let items = try container.decode([StudyItem].self, forKey: .items)
        try self.init(items: items)
    }

    public static func decode(from data: Data) throws -> StudyPlan {
        let decoder = JSONDecoder()
        let items = try decoder.decode([StudyItem].self, from: data)
        return try StudyPlan(items: items)
    }

    public func items(in category: StudyCategory) -> [StudyItem] {
        items.filter { $0.category == category }
    }

    public func incompleteMinutes() -> Int {
        items
            .filter { !$0.isCompleted }
            .reduce(0) { total, item in total + item.estimatedMinutes }
    }

    public mutating func markCompleted(id: String) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw StudyPlanError.unknownID(id)
        }
        items[index].markAsCompleted()
    }

    public mutating func importMerging(_ importedItems: [StudyItem]) throws {
        var seenIDs = Set<String>()
        for item in importedItems {
            if seenIDs.contains(item.id) {
                throw StudyPlanError.duplicateID(item.id)
            }
            seenIDs.insert(item.id)
        }
        
        var mergedItems = items
        var newItems: [StudyItem] = []
        
        for importedItem in importedItems {
            if let index = mergedItems.firstIndex(where: { $0.id == importedItem.id }) {
                mergedItems[index] = importedItem
            } else {
                newItems.append(importedItem)
            }
        }
        
        newItems.sort { $0.id < $1.id }
        mergedItems.append(contentsOf: newItems)
        
        items = mergedItems
    }
}
