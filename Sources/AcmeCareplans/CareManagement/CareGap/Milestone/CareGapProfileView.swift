import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap profile.
    final class CareGapProfileView {
        var codeText: String
        var name: String
        var graceDaysText: String
        var active: String
        var revision: String
        var endsAt: String
        var bed: String
        var copayText: String
        var specialtyText: String
        var statusLabel: String

        init(codeText: String, name: String, graceDaysText: String, active: String, revision: String, endsAt: String, bed: String, copayText: String, specialtyText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.graceDaysText = graceDaysText
            self.active = active
            self.revision = revision
            self.endsAt = endsAt
            self.bed = bed
            self.copayText = copayText
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapProfileView(_ item: CareGapProfile) -> CareGapProfileView {
        return CareGapProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            graceDaysText: String(item.graceDays),
            active: "\(item.active)",
            revision: String(item.revision),
            endsAt: String(item.endsAt),
            bed: item.bed,
            copayText: String(format: "%.2f", item.copay),
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapProfileViews(_ items: [CareGapProfile]) -> [CareGapProfileView] {
        var views: [CareGapProfileView] = []
        for item in items {
            views.append(toCareGapProfileView(item))
        }
        return views
    }

    static func sumCareGapProfileView(_ view: CareGapProfileView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRevision) + Double(parsedEndsAt)
    }
}
