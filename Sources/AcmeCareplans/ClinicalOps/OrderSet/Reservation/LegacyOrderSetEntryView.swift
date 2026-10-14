import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy order set entry.
    final class LegacyOrderSetEntryView {
        var code: String
        var label: String
        var phone: String
        var ratio: String
        var titleText: String
        var patientRef: String
        var description: String
        var retries: String
        var refills: String
        var bed: String
        var specialtyText: String
        var statusLabel: String

        init(code: String, label: String, phone: String, ratio: String, titleText: String, patientRef: String, description: String, retries: String, refills: String, bed: String, specialtyText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phone = phone
            self.ratio = ratio
            self.titleText = titleText
            self.patientRef = patientRef
            self.description = description
            self.retries = retries
            self.refills = refills
            self.bed = bed
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOrderSetEntryView(_ item: LegacyOrderSetEntry) -> LegacyOrderSetEntryView {
        return LegacyOrderSetEntryView(
            code: item.code,
            label: item.label,
            phone: item.phone,
            ratio: String(format: "%.2f", item.ratio),
            titleText: item.title,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            description: item.description,
            retries: String(item.retries),
            refills: String(item.refills),
            bed: item.bed,
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOrderSetEntryViews(_ items: [LegacyOrderSetEntry]) -> [LegacyOrderSetEntryView] {
        var views: [LegacyOrderSetEntryView] = []
        for item in items {
            views.append(toLegacyOrderSetEntryView(item))
        }
        return views
    }

    static func sumLegacyOrderSetEntryView(_ view: LegacyOrderSetEntryView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRatio + Double(parsedRetries) + Double(parsedRefills)
    }
}
