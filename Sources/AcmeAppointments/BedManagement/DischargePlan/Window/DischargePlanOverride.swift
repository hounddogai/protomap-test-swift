import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan override is in its life cycle.
    enum DischargePlanOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a discharge plan override and its current status.
    final class DischargePlanOverride {
        var code: String
        var name: String
        var country: String
        var refills: Int
        var sequence: Int
        var attempts: Int
        var createdAt: Int
        var status: DischargePlanOverrideStatus

        init(code: String, name: String, country: String, refills: Int, sequence: Int, attempts: Int, createdAt: Int, status: DischargePlanOverrideStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.refills = refills
            self.sequence = sequence
            self.attempts = attempts
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DischargePlanOverrideStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == DischargePlanOverrideStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DischargePlanOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return (Double(sequence) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanOverride {
            return DischargePlanOverride(
                code: code,
                name: name,
                country: country,
                refills: refills,
                sequence: sequence,
                attempts: attempts,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a discharge plan override in status new.
    static func newDischargePlanOverride(_ code: String, name: String) -> DischargePlanOverride {
        return DischargePlanOverride(
            code: code,
            name: name,
            country: "",
            refills: 0,
            sequence: 0,
            attempts: 0,
            createdAt: 0,
            status: DischargePlanOverrideStatus.new
        )
    }
}
