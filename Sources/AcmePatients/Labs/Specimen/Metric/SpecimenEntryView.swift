import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen entry.
    final class SpecimenEntryView {
        var code: String
        var label: String
        var source: String
        var updatedAt: String
        var segment: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, source: String, updatedAt: String, segment: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.updatedAt = updatedAt
            self.segment = segment
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenEntryView(_ item: SpecimenEntry) -> SpecimenEntryView {
        return SpecimenEntryView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            source: Kit.Text.truncate(item.source, limit: 80),
            updatedAt: String(item.updatedAt),
            segment: item.segment,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenEntryViews(_ items: [SpecimenEntry]) -> [SpecimenEntryView] {
        var views: [SpecimenEntryView] = []
        for item in items {
            views.append(toSpecimenEntryView(item))
        }
        return views
    }

    static func sumSpecimenEntryView(_ view: SpecimenEntryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
