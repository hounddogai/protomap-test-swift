import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession quota is in its life cycle.
    enum AccessionQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a accession quota and its current status.
    final class AccessionQuota {
        var code: String
        var name: String
        var specialty: String
        var allergy: String
        var batchSize: Int
        var quantity: Int
        var summary: String
        var diagnosisCode: String
        var copay: Double
        var segment: String
        var status: AccessionQuotaStatus

        init(code: String, name: String, specialty: String, allergy: String, batchSize: Int, quantity: Int, summary: String, diagnosisCode: String, copay: Double, segment: String, status: AccessionQuotaStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.allergy = allergy
            self.batchSize = batchSize
            self.quantity = quantity
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.segment = segment
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

        func canMoveTo(_ next: AccessionQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AccessionQuotaStatus.draining || next == AccessionQuotaStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AccessionQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(quantity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> AccessionQuota {
            return AccessionQuota(
                code: code,
                name: name,
                specialty: specialty,
                allergy: allergy,
                batchSize: batchSize,
                quantity: quantity,
                summary: summary,
                diagnosisCode: diagnosisCode,
                copay: copay,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a accession quota in status idle.
    static func newAccessionQuota(_ code: String, name: String) -> AccessionQuota {
        return AccessionQuota(
            code: code,
            name: name,
            specialty: "",
            allergy: "",
            batchSize: 0,
            quantity: 0,
            summary: "",
            diagnosisCode: "",
            copay: 0.0,
            segment: "",
            status: AccessionQuotaStatus.idle
        )
    }
}
