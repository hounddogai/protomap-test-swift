import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach plan is in its life cycle.
    enum PrimaryOutreachPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary outreach plan as the outreach team keeps it.
    final class PrimaryOutreachPlan {
        var code: String
        var name: String
        var discount: Double
        var channel: String
        var region: String
        var version: Int
        var sequence: Int
        var margin: Double
        var threshold: Double
        var unit: String
        var bed: String
        var status: PrimaryOutreachPlanStatus

        init(code: String, name: String, discount: Double, channel: String, region: String, version: Int, sequence: Int, margin: Double, threshold: Double, unit: String, bed: String, status: PrimaryOutreachPlanStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.channel = channel
            self.region = region
            self.version = version
            self.sequence = sequence
            self.margin = margin
            self.threshold = threshold
            self.unit = unit
            self.bed = bed
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

        func canMoveTo(_ next: PrimaryOutreachPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryOutreachPlanStatus.rejected || next == PrimaryOutreachPlanStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryOutreachPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOutreachPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return ((margin - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOutreachPlan {
            return PrimaryOutreachPlan(
                code: code,
                name: name,
                discount: discount,
                channel: channel,
                region: region,
                version: version,
                sequence: sequence,
                margin: margin,
                threshold: threshold,
                unit: unit,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary outreach plan in status proposed.
    static func newPrimaryOutreachPlan(_ code: String, name: String) -> PrimaryOutreachPlan {
        return PrimaryOutreachPlan(
            code: code,
            name: name,
            discount: 0.0,
            channel: "",
            region: "",
            version: 0,
            sequence: 0,
            margin: 0.0,
            threshold: 0.0,
            unit: "",
            bed: "",
            status: PrimaryOutreachPlanStatus.proposed
        )
    }
}
