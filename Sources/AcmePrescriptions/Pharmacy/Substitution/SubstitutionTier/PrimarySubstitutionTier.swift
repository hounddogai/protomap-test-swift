import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution tier is in its life cycle.
    enum PrimarySubstitutionTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary substitution tier. Its code is unique within a tenant.
    final class PrimarySubstitutionTier {
        var code: String
        var label: String
        var createdAt: Int
        var segment: String
        var patientRef: String
        var approved: Bool
        var notes: String
        var quantity: Int
        var phone: String
        var startsAt: Int
        var status: PrimarySubstitutionTierStatus

        init(code: String, label: String, createdAt: Int, segment: String, patientRef: String, approved: Bool, notes: String, quantity: Int, phone: String, startsAt: Int, status: PrimarySubstitutionTierStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.segment = segment
            self.patientRef = patientRef
            self.approved = approved
            self.notes = notes
            self.quantity = quantity
            self.phone = phone
            self.startsAt = startsAt
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

        func canMoveTo(_ next: PrimarySubstitutionTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimarySubstitutionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(startsAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionTier {
            return PrimarySubstitutionTier(
                code: code,
                label: label,
                createdAt: createdAt,
                segment: segment,
                patientRef: patientRef,
                approved: approved,
                notes: notes,
                quantity: quantity,
                phone: phone,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary substitution tier in status created.
    static func newPrimarySubstitutionTier(_ code: String, label: String) -> PrimarySubstitutionTier {
        return PrimarySubstitutionTier(
            code: code,
            label: label,
            createdAt: 0,
            segment: "",
            patientRef: "",
            approved: false,
            notes: "",
            quantity: 0,
            phone: "",
            startsAt: 0,
            status: PrimarySubstitutionTierStatus.created
        )
    }
}
