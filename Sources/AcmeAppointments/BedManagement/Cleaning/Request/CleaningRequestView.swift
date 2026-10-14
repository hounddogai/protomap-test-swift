import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning request.
    final class CleaningRequestView {
        var code: String
        var name: String
        var maximumText: String
        var retries: String
        var discount: String
        var visitMinutes: String
        var encounterID: String
        var sequence: String
        var minimum: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, name: String, maximumText: String, retries: String, discount: String, visitMinutes: String, encounterID: String, sequence: String, minimum: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximumText = maximumText
            self.retries = retries
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.sequence = sequence
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningRequestView(_ item: CleaningRequest) -> CleaningRequestView {
        return CleaningRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 120),
            maximumText: String(format: "%.2f", item.maximum),
            retries: String(item.retries),
            discount: String(format: "%.2f", item.discount),
            visitMinutes: String(item.visitMinutes),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            sequence: String(item.sequence),
            minimum: String(format: "%.2f", item.minimum),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningRequestViews(_ items: [CleaningRequest]) -> [CleaningRequestView] {
        var views: [CleaningRequestView] = []
        for item in items {
            views.append(toCleaningRequestView(item))
        }
        return views
    }

    static func sumCleaningRequestView(_ view: CleaningRequestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + parsedDiscount
    }
}
