import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered referral assignment is in its life cycle.
    enum TieredReferralAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered referral assignment as the referral team keeps it.
    final class TieredReferralAssignment {
        var code: String
        var label: String
        var attributes: [String: String]
        var country: String
        var batchSize: Int
        var notes: String
        var priority: Int
        var category: String
        var visible: Bool
        var endsAt: Int
        var status: TieredReferralAssignmentStatus

        init(code: String, label: String, attributes: [String: String], country: String, batchSize: Int, notes: String, priority: Int, category: String, visible: Bool, endsAt: Int, status: TieredReferralAssignmentStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.country = country
            self.batchSize = batchSize
            self.notes = notes
            self.priority = priority
            self.category = category
            self.visible = visible
            self.endsAt = endsAt
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

        func canMoveTo(_ next: TieredReferralAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredReferralAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReferralAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered referral assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
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

        func netVolume() -> Double {
            return ((Double(endsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferralAssignment {
            return TieredReferralAssignment(
                code: code,
                label: label,
                attributes: attributes,
                country: country,
                batchSize: batchSize,
                notes: notes,
                priority: priority,
                category: category,
                visible: visible,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered referral assignment in status proposed.
    static func newTieredReferralAssignment(_ code: String, label: String) -> TieredReferralAssignment {
        return TieredReferralAssignment(
            code: code,
            label: label,
            attributes: [:],
            country: "",
            batchSize: 0,
            notes: "",
            priority: 0,
            category: "",
            visible: false,
            endsAt: 0,
            status: TieredReferralAssignmentStatus.proposed
        )
    }
}
