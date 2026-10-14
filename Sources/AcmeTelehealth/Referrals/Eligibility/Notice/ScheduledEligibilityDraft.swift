import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled eligibility draft is in its life cycle.
    enum ScheduledEligibilityDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled eligibility draft. Its code is unique within a tenant.
    final class ScheduledEligibilityDraft {
        var code: String
        var name: String
        var ceiling: Double
        var ward: String
        var quantity: Int
        var checksum: String
        var expiresAt: Int
        var externalRef: String
        var cost: Double
        var ownerID: String
        var status: ScheduledEligibilityDraftStatus

        init(code: String, name: String, ceiling: Double, ward: String, quantity: Int, checksum: String, expiresAt: Int, externalRef: String, cost: Double, ownerID: String, status: ScheduledEligibilityDraftStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.ward = ward
            self.quantity = quantity
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.cost = cost
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ScheduledEligibilityDraftStatus) -> Bool {
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
                return next == ScheduledEligibilityDraftStatus.done
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: ScheduledEligibilityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled eligibility draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return (Double(expiresAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> ScheduledEligibilityDraft {
            return ScheduledEligibilityDraft(
                code: code,
                name: name,
                ceiling: ceiling,
                ward: ward,
                quantity: quantity,
                checksum: checksum,
                expiresAt: expiresAt,
                externalRef: externalRef,
                cost: cost,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled eligibility draft in status new.
    static func newScheduledEligibilityDraft(_ code: String, name: String) -> ScheduledEligibilityDraft {
        return ScheduledEligibilityDraft(
            code: code,
            name: name,
            ceiling: 0.0,
            ward: "",
            quantity: 0,
            checksum: "",
            expiresAt: 0,
            externalRef: "",
            cost: 0.0,
            ownerID: "",
            status: ScheduledEligibilityDraftStatus.new
        )
    }
}
