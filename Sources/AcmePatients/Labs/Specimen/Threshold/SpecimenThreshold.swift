import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen threshold is in its life cycle.
    enum SpecimenThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a specimen threshold and its current status.
    final class SpecimenThreshold {
        var code: String
        var title: String
        var durationMinutes: Int
        var diagnosisCode: String
        var checksum: String
        var payer: String
        var retries: Int
        var windowDays: Int
        var score: Double
        var status: SpecimenThresholdStatus

        init(code: String, title: String, durationMinutes: Int, diagnosisCode: String, checksum: String, payer: String, retries: Int, windowDays: Int, score: Double, status: SpecimenThresholdStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.payer = payer
            self.retries = retries
            self.windowDays = windowDays
            self.score = score
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

        func canMoveTo(_ next: SpecimenThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SpecimenThresholdStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: SpecimenThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((score + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenThreshold {
            return SpecimenThreshold(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                payer: payer,
                retries: retries,
                windowDays: windowDays,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen threshold in status idle.
    static func newSpecimenThreshold(_ code: String, title: String) -> SpecimenThreshold {
        return SpecimenThreshold(
            code: code,
            title: title,
            durationMinutes: 0,
            diagnosisCode: "",
            checksum: "",
            payer: "",
            retries: 0,
            windowDays: 0,
            score: 0.0,
            status: SpecimenThresholdStatus.idle
        )
    }
}
