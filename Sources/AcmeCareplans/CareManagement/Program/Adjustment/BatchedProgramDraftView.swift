import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched program draft.
    final class BatchedProgramDraftView {
        var codeText: String
        var title: String
        var limitText: String
        var notes: String
        var priorityText: String
        var externalRefText: String
        var statusLabel: String

        init(codeText: String, title: String, limitText: String, notes: String, priorityText: String, externalRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.limitText = limitText
            self.notes = notes
            self.priorityText = priorityText
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProgramDraftView(_ item: BatchedProgramDraft) -> BatchedProgramDraftView {
        return BatchedProgramDraftView(
            codeText: item.code,
            title: item.title,
            limitText: String(item.limit),
            notes: item.notes,
            priorityText: String(item.priority),
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProgramDraftViews(_ items: [BatchedProgramDraft]) -> [BatchedProgramDraftView] {
        var views: [BatchedProgramDraftView] = []
        for item in items {
            views.append(toBatchedProgramDraftView(item))
        }
        return views
    }

    static func sumBatchedProgramDraftView(_ view: BatchedProgramDraftView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority)
    }
}
