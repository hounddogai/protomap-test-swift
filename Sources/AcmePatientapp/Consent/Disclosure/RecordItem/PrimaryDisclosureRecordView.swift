import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary disclosure record.
    final class PrimaryDisclosureRecordView {
        var codeText: String
        var name: String
        var version: String
        var diagnosisCodeText: String
        var copay: String
        var statusLabel: String

        init(codeText: String, name: String, version: String, diagnosisCodeText: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.version = version
            self.diagnosisCodeText = diagnosisCodeText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDisclosureRecordView(_ item: PrimaryDisclosureRecord) -> PrimaryDisclosureRecordView {
        return PrimaryDisclosureRecordView(
            codeText: item.code,
            name: item.name,
            version: String(item.version),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDisclosureRecordViews(_ items: [PrimaryDisclosureRecord]) -> [PrimaryDisclosureRecordView] {
        var views: [PrimaryDisclosureRecordView] = []
        for item in items {
            views.append(toPrimaryDisclosureRecordView(item))
        }
        return views
    }

    static func sumPrimaryDisclosureRecordView(_ view: PrimaryDisclosureRecordView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVersion) + parsedCopay
    }
}
