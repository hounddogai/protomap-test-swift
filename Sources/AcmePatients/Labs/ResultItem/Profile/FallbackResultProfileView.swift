import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback result profile.
    final class FallbackResultProfileView {
        var codeText: String
        var titleText: String
        var updatedAt: String
        var checksum: String
        var windowDays: String
        var description: String
        var notesText: String
        var dosageMg: String
        var cost: String
        var statusLabel: String

        init(codeText: String, titleText: String, updatedAt: String, checksum: String, windowDays: String, description: String, notesText: String, dosageMg: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.windowDays = windowDays
            self.description = description
            self.notesText = notesText
            self.dosageMg = dosageMg
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackResultProfileView(_ item: FallbackResultProfile) -> FallbackResultProfileView {
        return FallbackResultProfileView(
            codeText: item.code,
            titleText: item.title,
            updatedAt: String(item.updatedAt),
            checksum: item.checksum,
            windowDays: String(item.windowDays),
            description: item.description,
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackResultProfileViews(_ items: [FallbackResultProfile]) -> [FallbackResultProfileView] {
        var views: [FallbackResultProfileView] = []
        for item in items {
            views.append(toFallbackResultProfileView(item))
        }
        return views
    }

    static func sumFallbackResultProfileView(_ view: FallbackResultProfileView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedWindowDays) + parsedDosageMg
    }
}
