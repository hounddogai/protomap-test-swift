import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool entries through their life cycle and keeps a journal of what it did.
    final class FloatPoolEntryService {
        var store: any FloatPoolEntryStore
        var validator: FloatPoolEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FloatPoolEntryStore, validator: FloatPoolEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newFloatPoolEntryService(_ store: any FloatPoolEntryStore, clock: any Kit.Clocks.Clock) -> FloatPoolEntryService {
        return FloatPoolEntryService(
            store: store,
            validator: defaultFloatPoolEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
