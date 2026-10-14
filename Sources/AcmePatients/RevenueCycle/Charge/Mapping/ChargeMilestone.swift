import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge milestone is in its life cycle.
    enum ChargeMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A charge milestone. Its code is unique within a tenant.
    final class ChargeMilestone {
        var code: String
        var label: String
        var attributes: [String: String]
        var payer: String
        var ward: String
        var retries: Int
        var encounterID: String
        var threshold: Double
        var ratio: Double
        var facility: String
        var status: ChargeMilestoneStatus

        init(code: String, label: String, attributes: [String: String], payer: String, ward: String, retries: Int, encounterID: String, threshold: Double, ratio: Double, facility: String, status: ChargeMilestoneStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.payer = payer
            self.ward = ward
            self.retries = retries
            self.encounterID = encounterID
            self.threshold = threshold
            self.ratio = ratio
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == ChargeMilestoneStatus.validated
            case .validated:
                return next == ChargeMilestoneStatus.published || next == ChargeMilestoneStatus.retired
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return (threshold * ratio * 100).rounded() / 100
        }

        func copyValue() -> ChargeMilestone {
            return ChargeMilestone(
                code: code,
                label: label,
                attributes: attributes,
                payer: payer,
                ward: ward,
                retries: retries,
                encounterID: encounterID,
                threshold: threshold,
                ratio: ratio,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a charge milestone in status created.
    static func newChargeMilestone(_ code: String, label: String) -> ChargeMilestone {
        return ChargeMilestone(
            code: code,
            label: label,
            attributes: [:],
            payer: "",
            ward: "",
            retries: 0,
            encounterID: "",
            threshold: 0.0,
            ratio: 0.0,
            facility: "",
            status: ChargeMilestoneStatus.created
        )
    }
}
