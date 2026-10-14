import AcmePlatform
import Foundation

extension Staffing {
    /// Moves manual overtime digests through their life cycle and keeps a journal of what it did.
    final class ManualOvertimeDigestService {
        var store: any ManualOvertimeDigestStore
        var validator: ManualOvertimeDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualOvertimeDigestEngine

        init(store: any ManualOvertimeDigestStore, validator: ManualOvertimeDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualOvertimeDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual overtime digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualOvertimeDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual overtime digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualOvertimeDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual overtime digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newManualOvertimeDigestService(_ store: any ManualOvertimeDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualOvertimeDigestService {
        return ManualOvertimeDigestService(
            store: store,
            validator: defaultManualOvertimeDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualOvertimeDigestEngine(flags)
        )
    }
}
