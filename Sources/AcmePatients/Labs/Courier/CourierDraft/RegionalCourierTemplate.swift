import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional courier template is in its life cycle.
    enum RegionalCourierTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional courier template, with what the planners need to act on it.
    final class RegionalCourierTemplate {
        var code: String
        var title: String
        var patientRef: String
        var retries: Int
        var facility: String
        var procedureCode: String
        var batchSize: Int
        var checksum: String
        var externalRef: String
        var ratio: Double
        var status: RegionalCourierTemplateStatus

        init(code: String, title: String, patientRef: String, retries: Int, facility: String, procedureCode: String, batchSize: Int, checksum: String, externalRef: String, ratio: Double, status: RegionalCourierTemplateStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.retries = retries
            self.facility = facility
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.checksum = checksum
            self.externalRef = externalRef
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalCourierTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalCourierTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional courier template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((Double(batchSize) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCourierTemplate {
            return RegionalCourierTemplate(
                code: code,
                title: title,
                patientRef: patientRef,
                retries: retries,
                facility: facility,
                procedureCode: procedureCode,
                batchSize: batchSize,
                checksum: checksum,
                externalRef: externalRef,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional courier template in status open.
    static func newRegionalCourierTemplate(_ code: String, title: String) -> RegionalCourierTemplate {
        return RegionalCourierTemplate(
            code: code,
            title: title,
            patientRef: "",
            retries: 0,
            facility: "",
            procedureCode: "",
            batchSize: 0,
            checksum: "",
            externalRef: "",
            ratio: 0.0,
            status: RegionalCourierTemplateStatus.`open`
        )
    }
}
