import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling slot agreement.
    final class RollingSlotAgreementView {
        var code: String
        var name: String
        var floorValue: String
        var batchSizeText: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, batchSizeText: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.batchSizeText = batchSizeText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSlotAgreementView(_ item: RollingSlotAgreement) -> RollingSlotAgreementView {
        return RollingSlotAgreementView(
            code: item.code,
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            batchSizeText: String(item.batchSize),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSlotAgreementViews(_ items: [RollingSlotAgreement]) -> [RollingSlotAgreementView] {
        var views: [RollingSlotAgreementView] = []
        for item in items {
            views.append(toRollingSlotAgreementView(item))
        }
        return views
    }

    static func sumRollingSlotAgreementView(_ view: RollingSlotAgreementView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedFloorValue + Double(parsedBatchSize) + Double(parsedSequence)
    }
}
