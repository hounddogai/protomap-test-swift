import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert agreement is in its life cycle.
    enum AlertAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A alert agreement. Its code is unique within a tenant.
    final class AlertAgreement {
        var code: String
        var name: String
        var diagnosisCode: String
        var createdAt: Int
        var phone: String
        var rate: Double
        var encounterID: String
        var priority: Int
        var segment: String
        var title: String
        var status: AlertAgreementStatus

        init(code: String, name: String, diagnosisCode: String, createdAt: Int, phone: String, rate: Double, encounterID: String, priority: Int, segment: String, title: String, status: AlertAgreementStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.phone = phone
            self.rate = rate
            self.encounterID = encounterID
            self.priority = priority
            self.segment = segment
            self.title = title
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

        func canMoveTo(_ next: AlertAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
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
                return next == AlertAgreementStatus.done
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

        func moveTo(_ next: AlertAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("alert agreement") \(code)"
        }

        func netVolume() -> Double {
            return ((rate + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AlertAgreement {
            return AlertAgreement(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                phone: phone,
                rate: rate,
                encounterID: encounterID,
                priority: priority,
                segment: segment,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert agreement in status new.
    static func newAlertAgreement(_ code: String, name: String) -> AlertAgreement {
        return AlertAgreement(
            code: code,
            name: name,
            diagnosisCode: "",
            createdAt: 0,
            phone: "",
            rate: 0.0,
            encounterID: "",
            priority: 0,
            segment: "",
            title: "",
            status: AlertAgreementStatus.new
        )
    }
}
