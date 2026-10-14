import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped claim forecast is in its life cycle.
    enum CappedClaimForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped claim forecast, with what the planners need to act on it.
    final class CappedClaimForecast {
        var code: String
        var name: String
        var clinicianID: String
        var checksum: String
        var channel: String
        var cost: Double
        var title: String
        var bed: String
        var revision: Int
        var patientRef: String
        var status: CappedClaimForecastStatus

        init(code: String, name: String, clinicianID: String, checksum: String, channel: String, cost: Double, title: String, bed: String, revision: Int, patientRef: String, status: CappedClaimForecastStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.channel = channel
            self.cost = cost
            self.title = title
            self.bed = bed
            self.revision = revision
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CappedClaimForecastStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedClaimForecastStatus.running
            case .queued:
                return next == CappedClaimForecastStatus.running || next == CappedClaimForecastStatus.done
            case .running:
                return next == CappedClaimForecastStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedClaimForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped claim forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("capped claim forecast") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((cost + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CappedClaimForecast {
            return CappedClaimForecast(
                code: code,
                name: name,
                clinicianID: clinicianID,
                checksum: checksum,
                channel: channel,
                cost: cost,
                title: title,
                bed: bed,
                revision: revision,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped claim forecast in status new.
    static func newCappedClaimForecast(_ code: String, name: String) -> CappedClaimForecast {
        return CappedClaimForecast(
            code: code,
            name: name,
            clinicianID: "",
            checksum: "",
            channel: "",
            cost: 0.0,
            title: "",
            bed: "",
            revision: 0,
            patientRef: "",
            status: CappedClaimForecastStatus.new
        )
    }
}
