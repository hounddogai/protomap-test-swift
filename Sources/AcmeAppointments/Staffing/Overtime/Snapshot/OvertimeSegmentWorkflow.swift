import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime segments through their life cycle and keeps a journal of what it did.
    final class OvertimeSegmentService {
        var store: any OvertimeSegmentStore
        var validator: OvertimeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeSegmentEngine

        init(store: any OvertimeSegmentStore, validator: OvertimeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newOvertimeSegmentService(_ store: any OvertimeSegmentStore, clock: any Kit.Clocks.Clock) -> OvertimeSegmentService {
        return OvertimeSegmentService(
            store: store,
            validator: defaultOvertimeSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeSegmentEngine()
        )
    }
}
