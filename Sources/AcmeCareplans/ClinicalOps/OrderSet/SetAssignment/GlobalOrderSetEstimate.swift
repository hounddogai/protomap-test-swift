import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global order set estimate is in its life cycle.
    enum GlobalOrderSetEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global order set estimate as the order set team keeps it.
    final class GlobalOrderSetEstimate {
        var code: String
        var title: String
        var priority: Int
        var archived: Bool
        var tags: [String]
        var discount: Double
        var version: Int
        var dosageMg: Double
        var status: GlobalOrderSetEstimateStatus

        init(code: String, title: String, priority: Int, archived: Bool, tags: [String], discount: Double, version: Int, dosageMg: Double, status: GlobalOrderSetEstimateStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.archived = archived
            self.tags = tags
            self.discount = discount
            self.version = version
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: GlobalOrderSetEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
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
                return next == GlobalOrderSetEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOrderSetEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global order set estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return (Double(priority) * discount * 100).rounded() / 100
        }

        func copyValue() -> GlobalOrderSetEstimate {
            return GlobalOrderSetEstimate(
                code: code,
                title: title,
                priority: priority,
                archived: archived,
                tags: tags,
                discount: discount,
                version: version,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global order set estimate in status new.
    static func newGlobalOrderSetEstimate(_ code: String, title: String) -> GlobalOrderSetEstimate {
        return GlobalOrderSetEstimate(
            code: code,
            title: title,
            priority: 0,
            archived: false,
            tags: [],
            discount: 0.0,
            version: 0,
            dosageMg: 0.0,
            status: GlobalOrderSetEstimateStatus.new
        )
    }
}
