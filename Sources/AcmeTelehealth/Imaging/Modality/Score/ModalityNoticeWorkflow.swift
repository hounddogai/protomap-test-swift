import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality notices through their life cycle and keeps a journal of what it did.
    final class ModalityNoticeService {
        var store: any ModalityNoticeStore
        var validator: ModalityNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ModalityNoticeStore, validator: ModalityNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityNoticeStatus.retired)
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

    static func newModalityNoticeService(_ store: any ModalityNoticeStore, clock: any Kit.Clocks.Clock) -> ModalityNoticeService {
        return ModalityNoticeService(
            store: store,
            validator: defaultModalityNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
