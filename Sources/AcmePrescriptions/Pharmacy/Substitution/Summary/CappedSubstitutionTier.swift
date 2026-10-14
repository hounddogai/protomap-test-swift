import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped substitution tier is in its life cycle.
    enum CappedSubstitutionTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped substitution tier. Its code is unique within a tenant.
    final class CappedSubstitutionTier {
        var code: String
        var name: String
        var region: String
        var refills: Int
        var notes: String
        var amount: Double
        var revision: Int
        var checksum: String
        var visible: Bool
        var status: CappedSubstitutionTierStatus

        init(code: String, name: String, region: String, refills: Int, notes: String, amount: Double, revision: Int, checksum: String, visible: Bool, status: CappedSubstitutionTierStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.refills = refills
            self.notes = notes
            self.amount = amount
            self.revision = revision
            self.checksum = checksum
            self.visible = visible
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

        func canMoveTo(_ next: CappedSubstitutionTierStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedSubstitutionTierStatus.validated || next == CappedSubstitutionTierStatus.retired
            case .validated:
                return next == CappedSubstitutionTierStatus.published || next == CappedSubstitutionTierStatus.retired
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

        func moveTo(_ next: CappedSubstitutionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped substitution tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (amount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CappedSubstitutionTier {
            return CappedSubstitutionTier(
                code: code,
                name: name,
                region: region,
                refills: refills,
                notes: notes,
                amount: amount,
                revision: revision,
                checksum: checksum,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped substitution tier in status created.
    static func newCappedSubstitutionTier(_ code: String, name: String) -> CappedSubstitutionTier {
        return CappedSubstitutionTier(
            code: code,
            name: name,
            region: "",
            refills: 0,
            notes: "",
            amount: 0.0,
            revision: 0,
            checksum: "",
            visible: false,
            status: CappedSubstitutionTierStatus.created
        )
    }
}
