import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted charge policy is in its life cycle.
    enum WeightedChargePolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted charge policy. Its code is unique within a tenant.
    final class WeightedChargePolicy {
        var code: String
        var label: String
        var contactEmail: String
        var createdAt: Int
        var description: String
        var visitMinutes: Int
        var name: String
        var region: String
        var status: WeightedChargePolicyStatus

        init(code: String, label: String, contactEmail: String, createdAt: Int, description: String, visitMinutes: Int, name: String, region: String, status: WeightedChargePolicyStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.description = description
            self.visitMinutes = visitMinutes
            self.name = name
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedChargePolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WeightedChargePolicyStatus.done || next == WeightedChargePolicyStatus.failed
            case .done:
                return next == WeightedChargePolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedChargePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted charge policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return (Double(createdAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WeightedChargePolicy {
            return WeightedChargePolicy(
                code: code,
                label: label,
                contactEmail: contactEmail,
                createdAt: createdAt,
                description: description,
                visitMinutes: visitMinutes,
                name: name,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted charge policy in status new.
    static func newWeightedChargePolicy(_ code: String, label: String) -> WeightedChargePolicy {
        return WeightedChargePolicy(
            code: code,
            label: label,
            contactEmail: "",
            createdAt: 0,
            description: "",
            visitMinutes: 0,
            name: "",
            region: "",
            status: WeightedChargePolicyStatus.new
        )
    }
}
