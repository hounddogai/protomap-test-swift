import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global study entry.
    final class GlobalStudyEntryView {
        var codeText: String
        var labelText: String
        var ownerIDText: String
        var budget: String
        var ratio: String
        var pinned: String
        var sequence: String
        var batchSizeText: String
        var maximumText: String
        var statusLabel: String

        init(codeText: String, labelText: String, ownerIDText: String, budget: String, ratio: String, pinned: String, sequence: String, batchSizeText: String, maximumText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ownerIDText = ownerIDText
            self.budget = budget
            self.ratio = ratio
            self.pinned = pinned
            self.sequence = sequence
            self.batchSizeText = batchSizeText
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalStudyEntryView(_ item: GlobalStudyEntry) -> GlobalStudyEntryView {
        return GlobalStudyEntryView(
            codeText: item.code,
            labelText: item.label,
            ownerIDText: item.ownerID,
            budget: String(format: "%.2f", item.budget),
            ratio: String(format: "%.2f", item.ratio),
            pinned: "\(item.pinned)",
            sequence: String(item.sequence),
            batchSizeText: String(item.batchSize),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalStudyEntryViews(_ items: [GlobalStudyEntry]) -> [GlobalStudyEntryView] {
        var views: [GlobalStudyEntryView] = []
        for item in items {
            views.append(toGlobalStudyEntryView(item))
        }
        return views
    }

    static func sumGlobalStudyEntryView(_ view: GlobalStudyEntryView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedBudget + parsedRatio + Double(parsedSequence)
    }
}
