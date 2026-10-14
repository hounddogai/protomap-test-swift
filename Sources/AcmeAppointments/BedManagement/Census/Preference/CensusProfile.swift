import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census profile is in its life cycle.
    enum CensusProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a census profile and its current status.
    final class CensusProfile {
        var code: String
        var title: String
        var batchSize: Int
        var ward: String
        var copay: Double
        var endsAt: Int
        var clinicianID: String
        var limit: Int
        var specialty: String
        var ratio: Double
        var acuity: Int
        var status: CensusProfileStatus

        init(code: String, title: String, batchSize: Int, ward: String, copay: Double, endsAt: Int, clinicianID: String, limit: Int, specialty: String, ratio: Double, acuity: Int, status: CensusProfileStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.ward = ward
            self.copay = copay
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.limit = limit
            self.specialty = specialty
            self.ratio = ratio
            self.acuity = acuity
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

        func canMoveTo(_ next: CensusProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CensusProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return ((Double(acuity) + copay) * 100).rounded() / 100
        }

        func copyValue() -> CensusProfile {
            return CensusProfile(
                code: code,
                title: title,
                batchSize: batchSize,
                ward: ward,
                copay: copay,
                endsAt: endsAt,
                clinicianID: clinicianID,
                limit: limit,
                specialty: specialty,
                ratio: ratio,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a census profile in status new.
    static func newCensusProfile(_ code: String, title: String) -> CensusProfile {
        return CensusProfile(
            code: code,
            title: title,
            batchSize: 0,
            ward: "",
            copay: 0.0,
            endsAt: 0,
            clinicianID: "",
            limit: 0,
            specialty: "",
            ratio: 0.0,
            acuity: 0,
            status: CensusProfileStatus.new
        )
    }
}
