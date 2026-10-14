import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality segment is in its life cycle.
    enum ModalitySegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A modality segment. Its code is unique within a tenant.
    final class ModalitySegment {
        var code: String
        var title: String
        var graceDays: Int
        var visible: Bool
        var phone: String
        var locale: String
        var weight: Double
        var maximum: Double
        var version: Int
        var refills: Int
        var amount: Double
        var status: ModalitySegmentStatus

        init(code: String, title: String, graceDays: Int, visible: Bool, phone: String, locale: String, weight: Double, maximum: Double, version: Int, refills: Int, amount: Double, status: ModalitySegmentStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.visible = visible
            self.phone = phone
            self.locale = locale
            self.weight = weight
            self.maximum = maximum
            self.version = version
            self.refills = refills
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

        func canMoveTo(_ next: ModalitySegmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ModalitySegmentStatus.running || next == ModalitySegmentStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ModalitySegmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalitySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((maximum + weight) * 100).rounded() / 100
        }

        func copyValue() -> ModalitySegment {
            return ModalitySegment(
                code: code,
                title: title,
                graceDays: graceDays,
                visible: visible,
                phone: phone,
                locale: locale,
                weight: weight,
                maximum: maximum,
                version: version,
                refills: refills,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a modality segment in status new.
    static func newModalitySegment(_ code: String, title: String) -> ModalitySegment {
        return ModalitySegment(
            code: code,
            title: title,
            graceDays: 0,
            visible: false,
            phone: "",
            locale: "",
            weight: 0.0,
            maximum: 0.0,
            version: 0,
            refills: 0,
            amount: 0.0,
            status: ModalitySegmentStatus.new
        )
    }
}
