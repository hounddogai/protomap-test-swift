import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped charge entry.
    final class CappedChargeEntryView {
        var codeText: String
        var title: String
        var copay: String
        var durationMinutes: String
        var versionText: String
        var batchSize: String
        var categoryText: String
        var visitMinutesText: String
        var notes: String
        var facility: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, title: String, copay: String, durationMinutes: String, versionText: String, batchSize: String, categoryText: String, visitMinutesText: String, notes: String, facility: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.versionText = versionText
            self.batchSize = batchSize
            self.categoryText = categoryText
            self.visitMinutesText = visitMinutesText
            self.notes = notes
            self.facility = facility
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedChargeEntryView(_ item: CappedChargeEntry) -> CappedChargeEntryView {
        return CappedChargeEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            durationMinutes: String(item.durationMinutes),
            versionText: String(item.version),
            batchSize: String(item.batchSize),
            categoryText: item.category,
            visitMinutesText: String(item.visitMinutes),
            notes: item.notes,
            facility: item.facility,
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedChargeEntryViews(_ items: [CappedChargeEntry]) -> [CappedChargeEntryView] {
        var views: [CappedChargeEntryView] = []
        for item in items {
            views.append(toCappedChargeEntryView(item))
        }
        return views
    }

    static func sumCappedChargeEntryView(_ view: CappedChargeEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + Double(parsedVersion)
    }
}
