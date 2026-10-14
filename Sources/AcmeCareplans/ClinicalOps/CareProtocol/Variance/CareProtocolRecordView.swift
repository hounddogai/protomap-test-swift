import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol record.
    final class CareProtocolRecordView {
        var code: String
        var name: String
        var refills: String
        var patientRef: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, refills: String, patientRef: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.refills = refills
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolRecordView(_ item: CareProtocolRecord) -> CareProtocolRecordView {
        return CareProtocolRecordView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            refills: String(item.refills),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolRecordViews(_ items: [CareProtocolRecord]) -> [CareProtocolRecordView] {
        var views: [CareProtocolRecordView] = []
        for item in items {
            views.append(toCareProtocolRecordView(item))
        }
        return views
    }

    static func sumCareProtocolRecordView(_ view: CareProtocolRecordView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRefills) + Double(parsedEndsAt)
    }
}
