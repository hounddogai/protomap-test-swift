import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback census metric is in its life cycle.
    enum FallbackCensusMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback census metric, with what the planners need to act on it.
    final class FallbackCensusMetric {
        var code: String
        var name: String
        var title: String
        var clinicianID: String
        var ratio: Double
        var refills: Int
        var allergy: String
        var status: FallbackCensusMetricStatus

        init(code: String, name: String, title: String, clinicianID: String, ratio: Double, refills: Int, allergy: String, status: FallbackCensusMetricStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.refills = refills
            self.allergy = allergy
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

        func canMoveTo(_ next: FallbackCensusMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCensusMetricStatus.granted || next == FallbackCensusMetricStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackCensusMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCensusMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback census metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback census metric") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCensusMetric {
            return FallbackCensusMetric(
                code: code,
                name: name,
                title: title,
                clinicianID: clinicianID,
                ratio: ratio,
                refills: refills,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback census metric in status requested.
    static func newFallbackCensusMetric(_ code: String, name: String) -> FallbackCensusMetric {
        return FallbackCensusMetric(
            code: code,
            name: name,
            title: "",
            clinicianID: "",
            ratio: 0.0,
            refills: 0,
            allergy: "",
            status: FallbackCensusMetricStatus.requested
        )
    }
}
