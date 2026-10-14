import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive acuity plan score is in its life cycle.
    enum AdaptiveAcuityPlanScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive acuity plan score, with what the planners need to act on it.
    final class AdaptiveAcuityPlanScore {
        var code: String
        var label: String
        var capacity: Int
        var endsAt: Int
        var country: String
        var sequence: Int
        var windowDays: Int
        var retries: Int
        var ward: String
        var status: AdaptiveAcuityPlanScoreStatus

        init(code: String, label: String, capacity: Int, endsAt: Int, country: String, sequence: Int, windowDays: Int, retries: Int, ward: String, status: AdaptiveAcuityPlanScoreStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.endsAt = endsAt
            self.country = country
            self.sequence = sequence
            self.windowDays = windowDays
            self.retries = retries
            self.ward = ward
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

        func canMoveTo(_ next: AdaptiveAcuityPlanScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AdaptiveAcuityPlanScoreStatus.done
            case .done:
                return next == AdaptiveAcuityPlanScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAcuityPlanScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive acuity plan score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive acuity plan score") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(endsAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAcuityPlanScore {
            return AdaptiveAcuityPlanScore(
                code: code,
                label: label,
                capacity: capacity,
                endsAt: endsAt,
                country: country,
                sequence: sequence,
                windowDays: windowDays,
                retries: retries,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive acuity plan score in status new.
    static func newAdaptiveAcuityPlanScore(_ code: String, label: String) -> AdaptiveAcuityPlanScore {
        return AdaptiveAcuityPlanScore(
            code: code,
            label: label,
            capacity: 0,
            endsAt: 0,
            country: "",
            sequence: 0,
            windowDays: 0,
            retries: 0,
            ward: "",
            status: AdaptiveAcuityPlanScoreStatus.new
        )
    }
}
