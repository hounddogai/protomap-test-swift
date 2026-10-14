import AcmePlatform
import Foundation

extension Imaging {
    /// Moves manual read estimates through their life cycle and keeps a journal of what it did.
    final class ManualReadEstimateManager {
        var store: any ManualReadEstimateStore
        var validator: ManualReadEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualReadEstimateStore, validator: ManualReadEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual read estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualReadEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual read estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualReadEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newManualReadEstimateManager(_ store: any ManualReadEstimateStore, clock: any Kit.Clocks.Clock) -> ManualReadEstimateManager {
        return ManualReadEstimateManager(
            store: store,
            validator: defaultManualReadEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
