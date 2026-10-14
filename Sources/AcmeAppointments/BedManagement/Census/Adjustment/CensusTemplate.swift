import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census template is in its life cycle.
    enum CensusTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A census template. Its code is unique within a tenant.
    final class CensusTemplate {
        var code: String
        var name: String
        var acuity: Int
        var quantity: Int
        var score: Double
        var durationMinutes: Int
        var weight: Double
        var summary: String
        var status: CensusTemplateStatus

        init(code: String, name: String, acuity: Int, quantity: Int, score: Double, durationMinutes: Int, weight: Double, summary: String, status: CensusTemplateStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.quantity = quantity
            self.score = score
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.summary = summary
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

        func canMoveTo(_ next: CensusTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CensusTemplateStatus.running || next == CensusTemplateStatus.done
            case .running:
                return next == CensusTemplateStatus.failed
            case .done:
                return next == CensusTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) + score) * 100).rounded() / 100
        }

        func copyValue() -> CensusTemplate {
            return CensusTemplate(
                code: code,
                name: name,
                acuity: acuity,
                quantity: quantity,
                score: score,
                durationMinutes: durationMinutes,
                weight: weight,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census template in status new.
    static func newCensusTemplate(_ code: String, name: String) -> CensusTemplate {
        return CensusTemplate(
            code: code,
            name: name,
            acuity: 0,
            quantity: 0,
            score: 0.0,
            durationMinutes: 0,
            weight: 0.0,
            summary: "",
            status: CensusTemplateStatus.new
        )
    }
}
