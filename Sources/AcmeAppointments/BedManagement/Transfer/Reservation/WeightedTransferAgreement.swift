import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer agreement is in its life cycle.
    enum WeightedTransferAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted transfer agreement and its current status.
    final class WeightedTransferAgreement {
        var code: String
        var title: String
        var margin: Double
        var quantity: Int
        var channel: String
        var patientRef: String
        var tags: [String]
        var threshold: Double
        var approved: Bool
        var status: WeightedTransferAgreementStatus

        init(code: String, title: String, margin: Double, quantity: Int, channel: String, patientRef: String, tags: [String], threshold: Double, approved: Bool, status: WeightedTransferAgreementStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.quantity = quantity
            self.channel = channel
            self.patientRef = patientRef
            self.tags = tags
            self.threshold = threshold
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedTransferAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedTransferAgreementStatus.granted || next == WeightedTransferAgreementStatus.expired
            case .granted:
                return next == WeightedTransferAgreementStatus.revoked || next == WeightedTransferAgreementStatus.expired
            case .revoked:
                return next == WeightedTransferAgreementStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return (Double(quantity) * threshold * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferAgreement {
            return WeightedTransferAgreement(
                code: code,
                title: title,
                margin: margin,
                quantity: quantity,
                channel: channel,
                patientRef: patientRef,
                tags: tags,
                threshold: threshold,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted transfer agreement in status requested.
    static func newWeightedTransferAgreement(_ code: String, title: String) -> WeightedTransferAgreement {
        return WeightedTransferAgreement(
            code: code,
            title: title,
            margin: 0.0,
            quantity: 0,
            channel: "",
            patientRef: "",
            tags: [],
            threshold: 0.0,
            approved: false,
            status: WeightedTransferAgreementStatus.requested
        )
    }
}
