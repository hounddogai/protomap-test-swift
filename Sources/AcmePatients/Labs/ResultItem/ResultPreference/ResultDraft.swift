import AcmePlatform
import Foundation

extension Labs {
    /// Where a result draft is in its life cycle.
    enum ResultDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result draft. Its code is unique within a tenant.
    final class ResultDraft {
        var code: String
        var name: String
        var procedureCode: String
        var checksum: String
        var notes: String
        var weight: Double
        var approved: Bool
        var durationMinutes: Int
        var status: ResultDraftStatus

        init(code: String, name: String, procedureCode: String, checksum: String, notes: String, weight: Double, approved: Bool, durationMinutes: Int, status: ResultDraftStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.notes = notes
            self.weight = weight
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ResultDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ResultDraft {
            return ResultDraft(
                code: code,
                name: name,
                procedureCode: procedureCode,
                checksum: checksum,
                notes: notes,
                weight: weight,
                approved: approved,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a result draft in status requested.
    static func newResultDraft(_ code: String, name: String) -> ResultDraft {
        return ResultDraft(
            code: code,
            name: name,
            procedureCode: "",
            checksum: "",
            notes: "",
            weight: 0.0,
            approved: false,
            durationMinutes: 0,
            status: ResultDraftStatus.requested
        )
    }
}
