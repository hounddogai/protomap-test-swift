import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional float pool override is in its life cycle.
    enum RegionalFloatPoolOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional float pool override as the float pool team keeps it.
    final class RegionalFloatPoolOverride {
        var code: String
        var title: String
        var description: String
        var category: String
        var attributes: [String: String]
        var batchSize: Int
        var checksum: String
        var diagnosisCode: String
        var budget: Double
        var ownerID: String
        var summary: String
        var status: RegionalFloatPoolOverrideStatus

        init(code: String, title: String, description: String, category: String, attributes: [String: String], batchSize: Int, checksum: String, diagnosisCode: String, budget: Double, ownerID: String, summary: String, status: RegionalFloatPoolOverrideStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.category = category
            self.attributes = attributes
            self.batchSize = batchSize
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.ownerID = ownerID
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalFloatPoolOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalFloatPoolOverrideStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalFloatPoolOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional float pool override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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
            return (budget * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFloatPoolOverride {
            return RegionalFloatPoolOverride(
                code: code,
                title: title,
                description: description,
                category: category,
                attributes: attributes,
                batchSize: batchSize,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                budget: budget,
                ownerID: ownerID,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional float pool override in status planned.
    static func newRegionalFloatPoolOverride(_ code: String, title: String) -> RegionalFloatPoolOverride {
        return RegionalFloatPoolOverride(
            code: code,
            title: title,
            description: "",
            category: "",
            attributes: [:],
            batchSize: 0,
            checksum: "",
            diagnosisCode: "",
            budget: 0.0,
            ownerID: "",
            summary: "",
            status: RegionalFloatPoolOverrideStatus.planned
        )
    }
}
