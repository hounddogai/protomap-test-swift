import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict discharge plan policy is in its life cycle.
    enum StrictDischargePlanPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One strict discharge plan policy, with what the planners need to act on it.
    final class StrictDischargePlanPolicy {
        var code: String
        var name: String
        var archived: Bool
        var dosageMg: Double
        var allergy: String
        var margin: Double
        var sequence: Int
        var minimum: Double
        var segment: String
        var externalRef: String
        var region: String
        var status: StrictDischargePlanPolicyStatus

        init(code: String, name: String, archived: Bool, dosageMg: Double, allergy: String, margin: Double, sequence: Int, minimum: Double, segment: String, externalRef: String, region: String, status: StrictDischargePlanPolicyStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.margin = margin
            self.sequence = sequence
            self.minimum = minimum
            self.segment = segment
            self.externalRef = externalRef
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictDischargePlanPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictDischargePlanPolicyStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StrictDischargePlanPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictDischargePlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict discharge plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedVolume() -> Double {
            return ((minimum - margin) * 100).rounded() / 100
        }

        func copyValue() -> StrictDischargePlanPolicy {
            return StrictDischargePlanPolicy(
                code: code,
                name: name,
                archived: archived,
                dosageMg: dosageMg,
                allergy: allergy,
                margin: margin,
                sequence: sequence,
                minimum: minimum,
                segment: segment,
                externalRef: externalRef,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict discharge plan policy in status proposed.
    static func newStrictDischargePlanPolicy(_ code: String, name: String) -> StrictDischargePlanPolicy {
        return StrictDischargePlanPolicy(
            code: code,
            name: name,
            archived: false,
            dosageMg: 0.0,
            allergy: "",
            margin: 0.0,
            sequence: 0,
            minimum: 0.0,
            segment: "",
            externalRef: "",
            region: "",
            status: StrictDischargePlanPolicyStatus.proposed
        )
    }
}
