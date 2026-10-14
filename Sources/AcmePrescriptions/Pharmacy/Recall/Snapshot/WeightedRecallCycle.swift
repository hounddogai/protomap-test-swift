import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted recall cycle is in its life cycle.
    enum WeightedRecallCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted recall cycle as the recall team keeps it.
    final class WeightedRecallCycle {
        var code: String
        var name: String
        var tags: [String]
        var country: String
        var minimum: Double
        var clinicianID: String
        var checksum: String
        var approved: Bool
        var expiresAt: Int
        var status: WeightedRecallCycleStatus

        init(code: String, name: String, tags: [String], country: String, minimum: Double, clinicianID: String, checksum: String, approved: Bool, expiresAt: Int, status: WeightedRecallCycleStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.country = country
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.approved = approved
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRecallCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedRecallCycleStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedRecallCycleStatus.suspended || next == WeightedRecallCycleStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WeightedRecallCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted recall cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((minimum + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRecallCycle {
            return WeightedRecallCycle(
                code: code,
                name: name,
                tags: tags,
                country: country,
                minimum: minimum,
                clinicianID: clinicianID,
                checksum: checksum,
                approved: approved,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted recall cycle in status draft.
    static func newWeightedRecallCycle(_ code: String, name: String) -> WeightedRecallCycle {
        return WeightedRecallCycle(
            code: code,
            name: name,
            tags: [],
            country: "",
            minimum: 0.0,
            clinicianID: "",
            checksum: "",
            approved: false,
            expiresAt: 0,
            status: WeightedRecallCycleStatus.draft
        )
    }
}
