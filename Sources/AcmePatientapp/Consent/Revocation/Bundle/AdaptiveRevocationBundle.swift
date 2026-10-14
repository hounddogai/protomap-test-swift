import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive revocation bundle is in its life cycle.
    enum AdaptiveRevocationBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a adaptive revocation bundle and its current status.
    final class AdaptiveRevocationBundle {
        var code: String
        var title: String
        var pinned: Bool
        var allergy: String
        var threshold: Double
        var contactEmail: String
        var attempts: Int
        var capacity: Int
        var ward: String
        var status: AdaptiveRevocationBundleStatus

        init(code: String, title: String, pinned: Bool, allergy: String, threshold: Double, contactEmail: String, attempts: Int, capacity: Int, ward: String, status: AdaptiveRevocationBundleStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.allergy = allergy
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.capacity = capacity
            self.ward = ward
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

        func canMoveTo(_ next: AdaptiveRevocationBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveRevocationBundleStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveRevocationBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive revocation bundle") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(attempts) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRevocationBundle {
            return AdaptiveRevocationBundle(
                code: code,
                title: title,
                pinned: pinned,
                allergy: allergy,
                threshold: threshold,
                contactEmail: contactEmail,
                attempts: attempts,
                capacity: capacity,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive revocation bundle in status new.
    static func newAdaptiveRevocationBundle(_ code: String, title: String) -> AdaptiveRevocationBundle {
        return AdaptiveRevocationBundle(
            code: code,
            title: title,
            pinned: false,
            allergy: "",
            threshold: 0.0,
            contactEmail: "",
            attempts: 0,
            capacity: 0,
            ward: "",
            status: AdaptiveRevocationBundleStatus.new
        )
    }
}
