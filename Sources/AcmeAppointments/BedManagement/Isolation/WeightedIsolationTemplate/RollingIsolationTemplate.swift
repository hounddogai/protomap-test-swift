import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling isolation template is in its life cycle.
    enum RollingIsolationTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rolling isolation template and its current status.
    final class RollingIsolationTemplate {
        var code: String
        var label: String
        var country: String
        var refills: Int
        var quantity: Int
        var name: String
        var title: String
        var visible: Bool
        var ratio: Double
        var bed: String
        var status: RollingIsolationTemplateStatus

        init(code: String, label: String, country: String, refills: Int, quantity: Int, name: String, title: String, visible: Bool, ratio: Double, bed: String, status: RollingIsolationTemplateStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.refills = refills
            self.quantity = quantity
            self.name = name
            self.title = title
            self.visible = visible
            self.ratio = ratio
            self.bed = bed
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

        func canMoveTo(_ next: RollingIsolationTemplateStatus) -> Bool {
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
                return next == RollingIsolationTemplateStatus.stopped
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

        func moveTo(_ next: RollingIsolationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling isolation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return ((Double(quantity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RollingIsolationTemplate {
            return RollingIsolationTemplate(
                code: code,
                label: label,
                country: country,
                refills: refills,
                quantity: quantity,
                name: name,
                title: title,
                visible: visible,
                ratio: ratio,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling isolation template in status idle.
    static func newRollingIsolationTemplate(_ code: String, label: String) -> RollingIsolationTemplate {
        return RollingIsolationTemplate(
            code: code,
            label: label,
            country: "",
            refills: 0,
            quantity: 0,
            name: "",
            title: "",
            visible: false,
            ratio: 0.0,
            bed: "",
            status: RollingIsolationTemplateStatus.idle
        )
    }
}
