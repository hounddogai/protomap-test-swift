import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback transfer template is in its life cycle.
    enum FallbackTransferTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback transfer template and its current status.
    final class FallbackTransferTemplate {
        var code: String
        var title: String
        var country: String
        var dosageMg: Double
        var createdAt: Int
        var floorValue: Double
        var diagnosisCode: String
        var status: FallbackTransferTemplateStatus

        init(code: String, title: String, country: String, dosageMg: Double, createdAt: Int, floorValue: Double, diagnosisCode: String, status: FallbackTransferTemplateStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: FallbackTransferTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackTransferTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback transfer template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback transfer template") \(code)"
        }

        func projectedExposure() -> Double {
            return ((floorValue - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTransferTemplate {
            return FallbackTransferTemplate(
                code: code,
                title: title,
                country: country,
                dosageMg: dosageMg,
                createdAt: createdAt,
                floorValue: floorValue,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback transfer template in status idle.
    static func newFallbackTransferTemplate(_ code: String, title: String) -> FallbackTransferTemplate {
        return FallbackTransferTemplate(
            code: code,
            title: title,
            country: "",
            dosageMg: 0.0,
            createdAt: 0,
            floorValue: 0.0,
            diagnosisCode: "",
            status: FallbackTransferTemplateStatus.idle
        )
    }
}
