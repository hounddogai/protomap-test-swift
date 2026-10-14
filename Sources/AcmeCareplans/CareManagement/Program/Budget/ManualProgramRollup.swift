import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual program rollup is in its life cycle.
    enum ManualProgramRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual program rollup as the program team keeps it.
    final class ManualProgramRollup {
        var code: String
        var name: String
        var attributes: [String: String]
        var country: String
        var region: String
        var source: String
        var approved: Bool
        var score: Double
        var ownerID: String
        var status: ManualProgramRollupStatus

        init(code: String, name: String, attributes: [String: String], country: String, region: String, source: String, approved: Bool, score: Double, ownerID: String, status: ManualProgramRollupStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.country = country
            self.region = region
            self.source = source
            self.approved = approved
            self.score = score
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

        func canMoveTo(_ next: ManualProgramRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualProgramRollupStatus.done || next == ManualProgramRollupStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ManualProgramRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualProgramRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual program rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualProgramRollup {
            return ManualProgramRollup(
                code: code,
                name: name,
                attributes: attributes,
                country: country,
                region: region,
                source: source,
                approved: approved,
                score: score,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual program rollup in status new.
    static func newManualProgramRollup(_ code: String, name: String) -> ManualProgramRollup {
        return ManualProgramRollup(
            code: code,
            name: name,
            attributes: [:],
            country: "",
            region: "",
            source: "",
            approved: false,
            score: 0.0,
            ownerID: "",
            status: ManualProgramRollupStatus.new
        )
    }
}
