import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial rollup is in its life cycle.
    enum DenialRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One denial rollup, with what the planners need to act on it.
    final class DenialRollup {
        var code: String
        var name: String
        var description: String
        var tags: [String]
        var margin: Double
        var unit: String
        var externalRef: String
        var ownerID: String
        var status: DenialRollupStatus

        init(code: String, name: String, description: String, tags: [String], margin: Double, unit: String, externalRef: String, ownerID: String, status: DenialRollupStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.tags = tags
            self.margin = margin
            self.unit = unit
            self.externalRef = externalRef
            self.ownerID = ownerID
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

        func canMoveTo(_ next: DenialRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == DenialRollupStatus.suspended || next == DenialRollupStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> DenialRollup {
            return DenialRollup(
                code: code,
                name: name,
                description: description,
                tags: tags,
                margin: margin,
                unit: unit,
                externalRef: externalRef,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a denial rollup in status draft.
    static func newDenialRollup(_ code: String, name: String) -> DenialRollup {
        return DenialRollup(
            code: code,
            name: name,
            description: "",
            tags: [],
            margin: 0.0,
            unit: "",
            externalRef: "",
            ownerID: "",
            status: DenialRollupStatus.draft
        )
    }
}
