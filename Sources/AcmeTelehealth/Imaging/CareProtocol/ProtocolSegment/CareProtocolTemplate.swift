import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol template is in its life cycle.
    enum CareProtocolTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol template. Its code is unique within a tenant.
    final class CareProtocolTemplate {
        var code: String
        var label: String
        var segment: String
        var ceiling: Double
        var locale: String
        var batchSize: Int
        var allergy: String
        var status: CareProtocolTemplateStatus

        init(code: String, label: String, segment: String, ceiling: Double, locale: String, batchSize: Int, allergy: String, status: CareProtocolTemplateStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.ceiling = ceiling
            self.locale = locale
            self.batchSize = batchSize
            self.allergy = allergy
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

        func canMoveTo(_ next: CareProtocolTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CareProtocolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((ceiling + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolTemplate {
            return CareProtocolTemplate(
                code: code,
                label: label,
                segment: segment,
                ceiling: ceiling,
                locale: locale,
                batchSize: batchSize,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a care protocol template in status new.
    static func newCareProtocolTemplate(_ code: String, label: String) -> CareProtocolTemplate {
        return CareProtocolTemplate(
            code: code,
            label: label,
            segment: "",
            ceiling: 0.0,
            locale: "",
            batchSize: 0,
            allergy: "",
            status: CareProtocolTemplateStatus.new
        )
    }
}
