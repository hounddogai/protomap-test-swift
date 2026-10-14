import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality mapping is in its life cycle.
    enum ModalityMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a modality mapping and its current status.
    final class ModalityMapping {
        var code: String
        var name: String
        var allergy: String
        var endsAt: Int
        var score: Double
        var facility: String
        var amount: Double
        var status: ModalityMappingStatus

        init(code: String, name: String, allergy: String, endsAt: Int, score: Double, facility: String, amount: Double, status: ModalityMappingStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.endsAt = endsAt
            self.score = score
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: ModalityMappingStatus) -> Bool {
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
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ModalityMappingStatus.failed
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

        func moveTo(_ next: ModalityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("modality mapping") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((amount + score) * 100).rounded() / 100
        }

        func copyValue() -> ModalityMapping {
            return ModalityMapping(
                code: code,
                name: name,
                allergy: allergy,
                endsAt: endsAt,
                score: score,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality mapping in status new.
    static func newModalityMapping(_ code: String, name: String) -> ModalityMapping {
        return ModalityMapping(
            code: code,
            name: name,
            allergy: "",
            endsAt: 0,
            score: 0.0,
            facility: "",
            amount: 0.0,
            status: ModalityMappingStatus.new
        )
    }
}
