import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read baseline.
    final class ReadBaselineView {
        var code: String
        var label: String
        var createdAtText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toReadBaselineView(_ item: ReadBaseline) -> ReadBaselineView {
        return ReadBaselineView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            createdAtText: String(item.createdAt),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadBaselineViews(_ items: [ReadBaseline]) -> [ReadBaselineView] {
        var views: [ReadBaselineView] = []
        for item in items {
            views.append(toReadBaselineView(item))
        }
        return views
    }

    static func sumReadBaselineView(_ view: ReadBaselineView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
