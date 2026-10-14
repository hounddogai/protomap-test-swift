import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped inventory cycle.
    final class CappedInventoryCycleView {
        var codeText: String
        var name: String
        var expiresAt: String
        var diagnosisCodeText: String
        var sequenceText: String
        var patientRefText: String
        var limit: String
        var statusLabel: String

        init(codeText: String, name: String, expiresAt: String, diagnosisCodeText: String, sequenceText: String, patientRefText: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.expiresAt = expiresAt
            self.diagnosisCodeText = diagnosisCodeText
            self.sequenceText = sequenceText
            self.patientRefText = patientRefText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toCappedInventoryCycleView(_ item: CappedInventoryCycle) -> CappedInventoryCycleView {
        return CappedInventoryCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            expiresAt: String(item.expiresAt),
            diagnosisCodeText: item.diagnosisCode,
            sequenceText: String(item.sequence),
            patientRefText: item.patientRef,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedInventoryCycleViews(_ items: [CappedInventoryCycle]) -> [CappedInventoryCycleView] {
        var views: [CappedInventoryCycleView] = []
        for item in items {
            views.append(toCappedInventoryCycleView(item))
        }
        return views
    }

    static func sumCappedInventoryCycleView(_ view: CappedInventoryCycleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedSequence) + Double(parsedLimit)
    }
}
