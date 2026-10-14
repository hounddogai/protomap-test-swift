import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan record.
    final class DischargePlanRecordView {
        var codeText: String
        var title: String
        var timezone: String
        var priorityText: String
        var minimum: String
        var versionText: String
        var copay: String
        var diagnosisCode: String
        var clinicianID: String
        var ward: String
        var notes: String
        var statusLabel: String

        init(codeText: String, title: String, timezone: String, priorityText: String, minimum: String, versionText: String, copay: String, diagnosisCode: String, clinicianID: String, ward: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.timezone = timezone
            self.priorityText = priorityText
            self.minimum = minimum
            self.versionText = versionText
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.clinicianID = clinicianID
            self.ward = ward
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanRecordView(_ item: DischargePlanRecord) -> DischargePlanRecordView {
        return DischargePlanRecordView(
            codeText: item.code,
            title: item.title,
            timezone: item.timezone,
            priorityText: String(item.priority),
            minimum: String(format: "%.2f", item.minimum),
            versionText: String(item.version),
            copay: String(format: "%.2f", item.copay),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            ward: item.ward,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanRecordViews(_ items: [DischargePlanRecord]) -> [DischargePlanRecordView] {
        var views: [DischargePlanRecordView] = []
        for item in items {
            views.append(toDischargePlanRecordView(item))
        }
        return views
    }

    static func sumDischargePlanRecordView(_ view: DischargePlanRecordView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedPriority) + parsedMinimum + Double(parsedVersion)
    }
}
