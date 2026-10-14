import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form batch is in its life cycle.
    enum ConsentFormBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One consent form batch, with what the planners need to act on it.
    final class ConsentFormBatch {
        var code: String
        var name: String
        var description: String
        var refills: Int
        var country: String
        var weight: Double
        var encounterID: String
        var dosageMg: Double
        var status: ConsentFormBatchStatus

        init(code: String, name: String, description: String, refills: Int, country: String, weight: Double, encounterID: String, dosageMg: Double, status: ConsentFormBatchStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.refills = refills
            self.country = country
            self.weight = weight
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ConsentFormBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ConsentFormBatchStatus.done || next == ConsentFormBatchStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ConsentFormBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form batch") \(code)"
        }

        func netExposure() -> Double {
            return ((dosageMg - weight) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormBatch {
            return ConsentFormBatch(
                code: code,
                name: name,
                description: description,
                refills: refills,
                country: country,
                weight: weight,
                encounterID: encounterID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a consent form batch in status new.
    static func newConsentFormBatch(_ code: String, name: String) -> ConsentFormBatch {
        return ConsentFormBatch(
            code: code,
            name: name,
            description: "",
            refills: 0,
            country: "",
            weight: 0.0,
            encounterID: "",
            dosageMg: 0.0,
            status: ConsentFormBatchStatus.new
        )
    }
}
