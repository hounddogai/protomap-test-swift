import AcmePlatform
import Foundation

extension Staffing {
    /// Moves lenient shift thresholds through their life cycle and keeps a journal of what it did.
    final class LenientShiftThresholdDesk {
        var store: any LenientShiftThresholdStore
        var validator: LenientShiftThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientShiftThresholdStore, validator: LenientShiftThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient shift threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientShiftThresholdStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient shift threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientShiftThresholdStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLenientShiftThresholdDesk(_ store: any LenientShiftThresholdStore, clock: any Kit.Clocks.Clock) -> LenientShiftThresholdDesk {
        return LenientShiftThresholdDesk(
            store: store,
            validator: defaultLenientShiftThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
