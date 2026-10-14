import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool cycles through their life cycle and keeps a journal of what it did.
    final class FloatPoolCycleService {
        var store: any FloatPoolCycleStore
        var validator: FloatPoolCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FloatPoolCycleStore, validator: FloatPoolCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolCycleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolCycleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFloatPoolCycleService(_ store: any FloatPoolCycleStore, clock: any Kit.Clocks.Clock) -> FloatPoolCycleService {
        return FloatPoolCycleService(
            store: store,
            validator: defaultFloatPoolCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
