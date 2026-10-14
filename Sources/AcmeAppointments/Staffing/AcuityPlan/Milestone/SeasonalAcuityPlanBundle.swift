import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal acuity plan bundle is in its life cycle.
    enum SeasonalAcuityPlanBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a seasonal acuity plan bundle and its current status.
    final class SeasonalAcuityPlanBundle {
        var code: String
        var title: String
        var category: String
        var name: String
        var limit: Int
        var dosageMg: Double
        var ward: String
        var refills: Int
        var version: Int
        var priority: Int
        var status: SeasonalAcuityPlanBundleStatus

        init(code: String, title: String, category: String, name: String, limit: Int, dosageMg: Double, ward: String, refills: Int, version: Int, priority: Int, status: SeasonalAcuityPlanBundleStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.name = name
            self.limit = limit
            self.dosageMg = dosageMg
            self.ward = ward
            self.refills = refills
            self.version = version
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalAcuityPlanBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SeasonalAcuityPlanBundleStatus.draining || next == SeasonalAcuityPlanBundleStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SeasonalAcuityPlanBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAcuityPlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal acuity plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("seasonal acuity plan bundle") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(priority) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAcuityPlanBundle {
            return SeasonalAcuityPlanBundle(
                code: code,
                title: title,
                category: category,
                name: name,
                limit: limit,
                dosageMg: dosageMg,
                ward: ward,
                refills: refills,
                version: version,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal acuity plan bundle in status idle.
    static func newSeasonalAcuityPlanBundle(_ code: String, title: String) -> SeasonalAcuityPlanBundle {
        return SeasonalAcuityPlanBundle(
            code: code,
            title: title,
            category: "",
            name: "",
            limit: 0,
            dosageMg: 0.0,
            ward: "",
            refills: 0,
            version: 0,
            priority: 0,
            status: SeasonalAcuityPlanBundleStatus.idle
        )
    }
}
